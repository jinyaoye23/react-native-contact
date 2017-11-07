package com.fenglu.react_native_contact;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.os.Build;
import android.os.Process;
import android.provider.ContactsContract;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.modules.core.PermissionAwareActivity;
import com.facebook.react.modules.core.PermissionListener;

import org.json.JSONException;
import org.json.JSONObject;


/**
 * Created by Jason on 2017/11/2.
 */

public class ContactModule extends ReactContextBaseJavaModule implements ActivityEventListener, PermissionListener {


    private  final ReactApplicationContext mReactContext;
    private static final int CONTACT_PICKER_RESULT = 1000;

    private static final String NO_PERMISSION = "10001";
    private static final String USER_CANCELED = "10002";
    private static final String OTHER_ERROR = "10003";


    private static final String LOG_TAG = "Contact Query";

    private  int mRequestCode = 0;

    public static final String CONTACT_READ = Manifest.permission.READ_CONTACTS;
    public static final String CONTACT_WRITE = Manifest.permission.WRITE_CONTACTS;
    private ContactAccessor contactAccessor;

    private Promise pickerPromise;

    public ContactModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mReactContext = reactContext;
        contactAccessor = new ContactAccessorSdk5(reactContext);
        reactContext.addActivityEventListener(this);
    }

    @Override
    public String getName() {
        return "RNContact";
    }

    @ReactMethod
    public void openContactPicker(Promise promise) {
        pickerPromise = promise;
        if (hasPermission(CONTACT_READ)) {
            // 有权限
            pickerContactAsync();
        } else {
            // 无权限
            requestPermission(CONTACT_READ);
        }
    }

    public  boolean hasPermission(String permission) {
        Context context = getReactApplicationContext().getBaseContext();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // android版本小于6.0
            return context.checkPermission(permission, Process.myPid(), Process.myUid()) == PackageManager.PERMISSION_GRANTED;
        } else {
            return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED;
        }
    }


    public void requestPermission(String permission) {
        mRequestCode ++;

        Context context = getReactApplicationContext().getBaseContext();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            if(context.checkPermission(permission, Process.myPid(), Process.myUid()) == PackageManager.PERMISSION_GRANTED) {
                pickerContactAsync();
            } else {
                pickerPromise.reject(NO_PERMISSION, "无访问通讯录权限");
            }
        } else {
            try {
                PermissionAwareActivity activity = getPermissionAwareActivity();
                activity.requestPermissions(new String[]{permission}, mRequestCode, this);

            } catch (IllegalStateException e) {
                pickerPromise.reject(OTHER_ERROR, "读取联系人失败");
            }
        }

    }

    private void pickerContactAsync() {

        new Thread(new Runnable() {
            @Override
            public void run() {
                Intent intent = new Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI);
                getCurrentActivity().startActivityForResult(intent, CONTACT_PICKER_RESULT);
            }
        }).start();
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {

        if (resultCode == Activity.RESULT_OK) {
            String contactId = data.getData().getLastPathSegment();

            Cursor c = getCurrentActivity().getContentResolver().query(ContactsContract.RawContacts.CONTENT_URI,
                    new String[] {ContactsContract.RawContacts._ID}, ContactsContract.RawContacts.CONTACT_ID + "=" + contactId, null, null);
            if (!c.moveToFirst()) {
                return;
            }
            String id = c.getString(c.getColumnIndex(ContactsContract.RawContacts._ID));
            c.close();

            try {

                JSONObject contact = contactAccessor.getContactById(id);

                pickerPromise.resolve(JsonConvertUtil.jsonToReact(contact));
            } catch (JSONException e) {
                Log.e(LOG_TAG, "JSONException", e);
            }
        } else if (resultCode == Activity.RESULT_CANCELED) {
            pickerPromise.reject(USER_CANCELED, "用户取消了选择联系人");
        }
    }

    @Override
    public void onNewIntent(Intent intent) {

    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

        if (requestCode == mRequestCode) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pickerContactAsync();
            } else {
                pickerPromise.reject(NO_PERMISSION, "无访问通讯录权限");
            }
        }

        return false;
    }

    private PermissionAwareActivity getPermissionAwareActivity() {
        Activity activity = getCurrentActivity();
        if (activity == null) {
            throw new IllegalStateException("Tried to use permissions API while not attached to an " +
                    "Activity.");
        } else if (!(activity instanceof PermissionAwareActivity)) {
            throw new IllegalStateException("Tried to use permissions API but the host Activity doesn't" +
                    " implement PermissionAwareActivity.");
        }
        return (PermissionAwareActivity) activity;
    }

}
