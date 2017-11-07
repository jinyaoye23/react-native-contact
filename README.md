# react-native-contact
# 安装：
> npm install -s https://github.com/fenglu09/react-native-contact.git
> react-native link react-native-contact


# 使用demo

```js
import ContactPicker from 'react-native-contact';

...

// 选择联系人
ContactPicker.pickContact().then(result => {
  console.log(result);
}).catch(error => {
  console.log(error);
});

```

# error
|code|说明|
|-|-|
|10001|NO_PERMISSION
|10002|USER_CANCELED
