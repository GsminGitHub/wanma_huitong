import 'package:redux/redux.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:wanma_huitong/common/config/config.dart';
import 'package:wanma_huitong/common/dao/result_dao.dart';
import 'package:wanma_huitong/common/db/provider/user_info_db_provider.dart';
import 'package:wanma_huitong/common/local/local_storage.dart';
import 'package:wanma_huitong/common/model/User.dart';
import 'package:wanma_huitong/common/net/http_manager.dart';
import 'package:wanma_huitong/common/redux/user_reducer.dart';
import 'package:wanma_huitong/common/utils/common_utils.dart';

class UserDao {
  static login(userName, password, store) async {
    String type = userName + ':' +password;
    var bytes = utf8.encode(type);
    var base64Str = base64.encode(bytes);
    if(Config.DEBUG) {
      print("base64Str login " + base64Str);
    }
    await LocalStorage.save(Config.USER_NAME_KEY, userName);
    await LocalStorage.save(Config.USER_BASIC_CODE, base64Str);

    Map requestParams = {
      'userName': userName,
      'password': password
    };

    HttpManager.clearAuthorization();

    var res = await HttpManager.netFetch('', json.encode(requestParams), null, Options(method: 'post'));
    var resultData;
    if(res != null && res.result) {
      await LocalStorage.save(Config.PW_KEY, password);
      User user = User(userName: userName, password: password);
      //存入数据库
      UserInfoDbProvider provider = UserInfoDbProvider();
      provider.insert(userName, password);

      var resultData = ResultDao(user, res.result);
      if (Config.DEBUG) {
        print("user result " + resultData.result.toString());
        print(resultData.data);
        print(res.data.toString());
      }
      store.dispatch(UpdateUserAction(resultData.data));
    }
    return ResultDao(resultData ?? null, res.result);
//      return ResultDao(data, true);
  }

  ///获取用户信息
  static getUserInfo(String userName) async {
    UserInfoDbProvider provider = UserInfoDbProvider();
    var res = await HttpManager.netFetch('', null, null, null);
  }

  static clearAll(Store store) async {
    HttpManager.clearAuthorization();
    LocalStorage.remove(Config.USER_INFO);
    store.dispatch(new UpdateUserAction(User.empty()));
  }

  static initUserInfo(Store store) async {
    //读取主题
    String themeIndex = await LocalStorage.get(Config.THEME_COLOR);
    if(themeIndex != null && themeIndex.length != 0) {
      CommonUtils.pushTheme(store, int.parse(themeIndex));
    }
  }
}