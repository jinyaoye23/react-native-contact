package com.fenglu.react_native_contact;

/**
 * Created by Jason on 2017/11/2.
 */

import java.util.HashMap;

import org.json.JSONArray;
import org.json.JSONObject;

public class ContactInfoDTO {

    String displayName;
    JSONObject name;
    JSONArray organizations;
    JSONArray addresses;
    JSONArray phones;
    JSONArray emails;
    JSONArray ims;
    JSONArray websites;
    JSONArray photos;
    String note;
    String nickname;
    String birthday;
    HashMap<String, Object> desiredFieldsWithVals;

    public ContactInfoDTO() {

        displayName = "";
        name = new JSONObject();
        organizations = new JSONArray();
        addresses = new JSONArray();
        phones = new JSONArray();
        emails = new JSONArray();
        ims = new JSONArray();
        websites = new JSONArray();
        photos = new JSONArray();
        note = "";
        nickname = "";
        desiredFieldsWithVals = new HashMap<String, Object>();
    }

}
