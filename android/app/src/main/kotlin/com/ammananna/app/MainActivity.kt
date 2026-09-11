package com.ammananna.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.ContentProviderOperation
import android.provider.ContactsContract
import android.accounts.AccountManager
import android.content.Context
import android.telecom.TelecomManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ammananna.app/direct_call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeCall") {
                val phoneNumber = call.argument<String>("phoneNumber")
                if (phoneNumber != null) {
                    val launched = makeDirectCall(phoneNumber)
                    if (launched) {
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "CALL_PHONE permission is required or not granted", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is null", null)
                }
            } else if (call.method == "shareToWhatsApp") {
                val imagePath = call.argument<String>("imagePath")
                val phoneNumber = call.argument<String>("phoneNumber")
                if (imagePath != null && phoneNumber != null) {
                    val shared = shareToWhatsApp(imagePath, phoneNumber)
                    result.success(shared)
                } else {
                    result.error("INVALID_ARGUMENT", "ImagePath or Phone number is null", null)
                }
            } else if (call.method == "saveContactNatively") {
                val name = call.argument<String>("name")
                val phone = call.argument<String>("phone")
                if (name != null && phone != null) {
                    val saved = saveContactNatively(name, phone)
                    result.success(saved)
                } else {
                    result.error("INVALID_ARGUMENT", "Name or Phone is null", null)
                }
            } else if (call.method == "updateContactNatively") {
                val id = call.argument<String>("id")
                val name = call.argument<String>("name")
                val phone = call.argument<String>("phone")
                if (id != null && name != null && phone != null) {
                    val updated = updateContactNatively(id, name, phone)
                    result.success(updated)
                } else {
                    result.error("INVALID_ARGUMENT", "ID, Name, or Phone is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isSuspectedCallerIdAdware(packageName: String): Boolean {
        val lower = packageName.lowercase()
        return lower.contains("callerid") ||
               lower.contains("caller.id") ||
               lower.contains("showcaller") ||
               lower.contains("truecaller") ||
               lower.contains("callapp") ||
               lower.contains("whoscall") ||
               lower.contains("eyecon") ||
               lower.contains("drupe") ||
               lower.contains("sync.me") ||
               lower.contains("numcaller") ||
               lower.contains("callblocker") ||
               lower.contains("spam") ||
               lower.contains("adware")
    }

    private fun makeDirectCall(phoneNumber: String): Boolean {
        val cleanNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
        if (cleanNumber.isEmpty()) return false

        val hasCallPermission = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED

        val tm = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
        val defaultDialer = tm?.defaultDialerPackage
        val userAccount = try {
            tm?.userSelectedOutgoingPhoneAccount
        } catch (e: Exception) {
            null
        }

        // Build list of trusted system dialers in order of priority:
        // 1. Google Phone (standard on Realme 8 5G, Moto, Pixel, Xiaomi, OnePlus)
        // 2. Default dialer (if set and NOT a third-party adware app)
        // 3. AOSP / standard Android telephony
        // 4. Samsung OneUI dialer
        // 5. Realme / ColorOS native dialer
        val trustedDialers = mutableListOf<String>()
        trustedDialers.add("com.google.android.dialer")
        if (!defaultDialer.isNullOrBlank() && !isSuspectedCallerIdAdware(defaultDialer) && !trustedDialers.contains(defaultDialer)) {
            trustedDialers.add(defaultDialer)
        }
        if (!trustedDialers.contains("com.android.phone")) trustedDialers.add("com.android.phone")
        if (!trustedDialers.contains("com.samsung.android.dialer")) trustedDialers.add("com.samsung.android.dialer")
        if (!trustedDialers.contains("com.coloros.phoneno")) trustedDialers.add("com.coloros.phoneno")

        if (hasCallPermission) {
            // Priority 1: Target clean system dialer explicitly with ACTION_CALL
            // This directly bypasses third-party adware / Caller ID overlays that produce blank white screens!
            for (pkg in trustedDialers) {
                try {
                    val callIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$cleanNumber")).apply {
                        setPackage(pkg)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        // Multi-SIM routing extras for MediaTek / Realme / ColorOS modems
                        putExtra("com.android.phone.extra.slot", 0)
                        putExtra("simSlot", 0)
                        putExtra("sim_slot", 0)
                        putExtra("slot", 0)
                        putExtra("Cdma_Supp", true)
                        if (userAccount != null) {
                            putExtra(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, userAccount)
                        }
                    }

                    if (callIntent.resolveActivity(packageManager) != null) {
                        startActivity(callIntent)
                        return true
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Priority 2: Generic ACTION_CALL, but ONLY if the resolved handler is NOT suspected adware
            try {
                val genericCallIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$cleanNumber")).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra("com.android.phone.extra.slot", 0)
                    putExtra("simSlot", 0)
                    putExtra("sim_slot", 0)
                    putExtra("slot", 0)
                    putExtra("Cdma_Supp", true)
                    if (userAccount != null) {
                        putExtra(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, userAccount)
                    }
                }
                val resolveInfo = genericCallIntent.resolveActivity(packageManager)
                val resolvedPackage = resolveInfo?.packageName ?: ""
                if (resolvedPackage.isNotEmpty() && !isSuspectedCallerIdAdware(resolvedPackage)) {
                    startActivity(genericCallIntent)
                    return true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // Priority 3: Safe fallback using ACTION_DIAL targeted to a trusted dialer (zero permission required)
        for (pkg in trustedDialers) {
            try {
                val dialIntent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleanNumber")).apply {
                    setPackage(pkg)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                if (dialIntent.resolveActivity(packageManager) != null) {
                    startActivity(dialIntent)
                    return true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // Priority 4: Ultimate generic dialer fallback
        return try {
            val fallbackDial = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleanNumber")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(fallbackDial)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun shareToWhatsApp(imagePath: String, phoneNumber: String): Boolean {
        val pm = packageManager
        val isWhatsAppInstalled = isPackageInstalled("com.whatsapp", pm)
        val isWhatsAppBusinessInstalled = isPackageInstalled("com.whatsapp.w4b", pm)

        if (!isWhatsAppInstalled && !isWhatsAppBusinessInstalled) {
            return false
        }

        return try {
            val file = java.io.File(imagePath)
            val uri = androidx.core.content.FileProvider.getUriForFile(
                this,
                "com.ammananna.app.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                
                // Clean phone number: remove non-digits
                val cleanPhone = phoneNumber.replace(Regex("[^0-9]"), "")
                // For 10-digit Indian mobile numbers, prepend international prefix 91
                val jidPhone = if (cleanPhone.length == 10) "91$cleanPhone" else cleanPhone
                putExtra("jid", "$jidPhone@s.whatsapp.net")
                
                if (isWhatsAppInstalled) {
                    setPackage("com.whatsapp")
                } else {
                    setPackage("com.whatsapp.w4b")
                }
                
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun isPackageInstalled(packageName: String, packageManager: PackageManager): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun saveContactNatively(name: String, phone: String): Boolean {
        val ops = ArrayList<ContentProviderOperation>()

        // 1. Try local/SIM account insert first (standard default)
        ops.add(ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
            .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
            .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
            .build())

        ops.add(ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
            .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
            .build())

        ops.add(ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
            .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
            .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone)
            .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
            .build())

        return try {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
            true
        } catch (e: IllegalArgumentException) {
            // Android 16 Cloud preference exception!
            e.printStackTrace()
            // Fallback to query available cloud/Google accounts and save to it directly
            trySaveToAvailableAccount(name, phone)
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun trySaveToAvailableAccount(name: String, phone: String): Boolean {
        return try {
            val am = AccountManager.get(this)
            val accounts = am.accounts
            var targetAccount: android.accounts.Account? = null
            if (accounts.isNotEmpty()) {
                // Prioritize Google Cloud accounts, fallback to first available
                targetAccount = accounts.firstOrNull { it.type == "com.google" } ?: accounts[0]
            }

            if (targetAccount != null) {
                val ops = ArrayList<ContentProviderOperation>()
                ops.add(ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, targetAccount.type)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, targetAccount.name)
                    .build())

                ops.add(ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                    .build())

                ops.add(ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone)
                    .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                    .build())

                contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun updateContactNatively(contactId: String, name: String, phone: String): Boolean {
        val rawContactIds = getRawContactIds(contactId)
        if (rawContactIds.isEmpty()) {
            return false
        }

        var totalUpdated = 0

        for (rawId in rawContactIds) {
            try {
                // 1. Update StructuredName entries associated with rawId
                val nameSelection = "${ContactsContract.Data.RAW_CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?"
                val nameSelectionArgs = arrayOf(rawId.toString(), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                
                val nameValues = android.content.ContentValues().apply {
                    put(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                    put(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, name)
                    put(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, "")
                    put(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, "")
                    put(ContactsContract.CommonDataKinds.StructuredName.PREFIX, "")
                    put(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, "")
                }
                
                val nameUpdated = contentResolver.update(
                    ContactsContract.Data.CONTENT_URI,
                    nameValues,
                    nameSelection,
                    nameSelectionArgs
                )
                
                if (nameUpdated == 0) {
                    // StructuredName row does not exist for this raw contact, insert it
                    nameValues.put(ContactsContract.Data.RAW_CONTACT_ID, rawId)
                    nameValues.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    val insertedUri = contentResolver.insert(ContactsContract.Data.CONTENT_URI, nameValues)
                    if (insertedUri != null) {
                        totalUpdated += 1
                    }
                } else {
                    totalUpdated += nameUpdated
                }

                // 2. Update Phone entries associated with rawId
                val phoneSelection = "${ContactsContract.Data.RAW_CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?"
                val phoneSelectionArgs = arrayOf(rawId.toString(), ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                
                val phoneValues = android.content.ContentValues().apply {
                    put(ContactsContract.CommonDataKinds.Phone.NUMBER, phone)
                    put(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                }
                
                val phoneUpdated = contentResolver.update(
                    ContactsContract.Data.CONTENT_URI,
                    phoneValues,
                    phoneSelection,
                    phoneSelectionArgs
                )
                
                if (phoneUpdated == 0) {
                    // Phone row does not exist for this raw contact, insert it
                    phoneValues.put(ContactsContract.Data.RAW_CONTACT_ID, rawId)
                    phoneValues.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    val insertedUri = contentResolver.insert(ContactsContract.Data.CONTENT_URI, phoneValues)
                    if (insertedUri != null) {
                        totalUpdated += 1
                    }
                } else {
                    totalUpdated += phoneUpdated
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return totalUpdated > 0
    }

    private fun getRawContactIds(contactId: String): List<Long> {
        val rawContactIds = ArrayList<Long>()
        val projection = arrayOf(
            ContactsContract.RawContacts._ID,
            ContactsContract.RawContacts.ACCOUNT_TYPE
        )
        val selection = "${ContactsContract.RawContacts.CONTACT_ID} = ?"
        val selectionArgs = arrayOf(contactId)
        
        val readOnlyAccountTypes = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "org.telegram",
            "com.facebook.auth.login",
            "com.facebook.messenger",
            "com.viber.voip",
            "com.skype.raider"
        )

        contentResolver.query(
            ContactsContract.RawContacts.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndex(ContactsContract.RawContacts._ID)
            val typeColumn = cursor.getColumnIndex(ContactsContract.RawContacts.ACCOUNT_TYPE)
            while (cursor.moveToNext()) {
                val rawId = cursor.getLong(idColumn)
                val accountType = cursor.getString(typeColumn) ?: ""
                if (!readOnlyAccountTypes.contains(accountType.lowercase())) {
                    rawContactIds.add(rawId)
                }
            }
        }
        return rawContactIds
    }
}
