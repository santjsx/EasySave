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

    private fun makeDirectCall(phoneNumber: String): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            return true
        }
        return false
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
                totalUpdated += nameUpdated

                // 2. Update Phone entries associated with rawId
                val phoneSelection = "${ContactsContract.Data.RAW_CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?"
                val phoneSelectionArgs = arrayOf(rawId.toString(), ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                
                val phoneValues = android.content.ContentValues().apply {
                    put(ContactsContract.CommonDataKinds.Phone.NUMBER, phone)
                }
                
                val phoneUpdated = contentResolver.update(
                    ContactsContract.Data.CONTENT_URI,
                    phoneValues,
                    phoneSelection,
                    phoneSelectionArgs
                )
                totalUpdated += phoneUpdated
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
