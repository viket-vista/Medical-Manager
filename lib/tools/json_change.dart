// ignore_for_file: non_constant_identifier_names

dynamic JsonChange(List<dynamic> path,dynamic inputjson,dynamic newdata){
  if (path.length<=1){
    if (inputjson is List&&path[0] is int&&inputjson.length>path[0]){
      inputjson[path[0]]=newdata;
      return inputjson;
    }else if(inputjson is Map){
      inputjson[path[0]]=newdata;
      return inputjson;
    }
  }else{
    if (inputjson is List&&path[0] is int&&inputjson.length>path[0]){
      final first=path[0];
      List<dynamic> remainingPath = List.from(path)..removeAt(0);
      inputjson[first]=JsonChange(remainingPath, inputjson[first], newdata);
      return inputjson;
    }else if(inputjson is Map){
      final first=path[0];
      List<dynamic> remainingPath = List.from(path)..removeAt(0);
      inputjson[first]=JsonChange(remainingPath, inputjson[first], newdata);
      return inputjson;
    }
  }
}
dynamic JsonAdd(List<dynamic> path, dynamic inputjson, dynamic newdata) {
  if (path.isEmpty) {
    return newdata; // 直接替换或插入最终数据
  }

  final first = path[0];
  final remainingPath = path.sublist(1);

  if (inputjson is Map) {
    if (inputjson[first] == null) {
      if (remainingPath.isNotEmpty && remainingPath[0] is int) {
        inputjson[first] = []; // 下一级是 list
      } else {
        inputjson[first] = {}; // 默认是 map
      }
    }
    inputjson[first] = JsonAdd(remainingPath, inputjson[first], newdata);
    return inputjson;
  } else if (inputjson is List && first is int) {
    // 补全中间缺失的索引
    while (inputjson.length <= first) {
      inputjson.add({});
    }
    inputjson[first] = JsonAdd(remainingPath, inputjson[first], newdata);
    return inputjson;
  } else {
    throw Exception("Invalid structure at path: $first");
  }
}
dynamic JsonDel(List<dynamic> path,dynamic inputjson){
  if (path.length<=1){
    if (inputjson is List&&path[0] is int&&inputjson.length>path[0]){
      inputjson.removeAt(path[0]);
      return inputjson;
    }else if(inputjson is Map){
      inputjson.remove(path[0]);
      return inputjson;
    }
  }else{
    if (inputjson is List&&path[0] is int&&inputjson.length>path[0]){
      final first=path[0];
      path.removeAt(0);
      inputjson[first]=JsonDel(path, inputjson[first]);
      return inputjson;
    }else if(inputjson is Map){
      final first=path[0];
      path.removeAt(0);
      inputjson[first]=JsonDel(path, inputjson[first]);
      return inputjson;
    }
  }
}