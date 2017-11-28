import { NativeModules, Platform } from 'react-native';

const isIOS = Platform.OS == 'ios';
export const ContactPickerStatus = {
    SUCCESS: '10000',
    NO_PERMISSION: '10001',   // 无权限
    USER_CANCELED: '10002',   // 用户取消
    OTHER_ERROR: '10003',     // 位置错误
}

function pickContact() {
    if (isIOS) {
        return new Promise((resolve, reject) => {
            NativeModules.RNContact.openContactPicker(result => {

                if (result.code == ContactPickerStatus.SUCCESS) {
                    console.log(result);
                    let data = result.data;
                    let name = data.name.formatted;
                    data.name = name;
                    resolve(data);
                } else {
                    reject({
                        code: result.code,
                        message: result.msg,
                    });
                }
            })
        })

    } else {
        return new Promise((resolve, reject) => {
            NativeModules.RNContact.openContactPicker().then(result => {

                result.name = result.displayName;
                resolve(result);
            }).catch(error => {
                reject({
                    code: error.code,
                });
            })
        })
    }

}

export default {
    pickContact
}
