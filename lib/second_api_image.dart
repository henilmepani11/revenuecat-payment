 import 'dart:convert';
import 'dart:typed_data';

class ApiService{
  uploadImage()async{
    var url=Uri.parse("");
    Uint8List bytes= await image.readAsBytes();
    var request=http.MultipartRequest("POST",url);
    var myFile=http.MultipartFile("file",http.ByteStream.fromBytes(bytes),bytes.length,filename:image.name);

    request.files.add(myFile);

    final response=await request.send();

    if(response.statusCode==200){
      var data=await response.stream.bytesToString();
      return jsonDecode(data);
    }else{
      return null;
    }
  }
 }