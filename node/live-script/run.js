var qiniu = require("qiniu");
var fs = require("fs");
var http = require("http");

fs.readFile("video.json","utf-8",function(err,str){
	var result = [];
	var resultStr = "";
	var isUploadFailed;
	var uploadCount = 0;
	var readData = JSON.parse(str);
	var timerId;

	qiniu.conf.ACCESS_KEY = readData.ACCESS_KEY;
	qiniu.conf.SECRET_KEY = readData.SECRET_KEY;

	var putPolicy =  new qiniu.rs.PutPolicy2({
		scope:'owhat-live',
		deadline:new Date().getTime + 3600 * 1000,
		returnBody:'{"key": $(key),"hash": $(etag),"name":$(fname)}',
		fsizeLimit:2048 * 1024 * 1024
	});

	function pullPfopResult(persistentId){
		console.log('convert video....');
		timerId = setInterval(function(){
			http.get("http://api.qiniu.com/status/get/prefop?id=" + persistentId,function(res){
				res.setEncoding('utf8');
				res.on('data',function(chunk){
					res = JSON.parse(chunk);
					if(res.code == 4){
						clearInterval(timerId);
						console.log("convert finished");
						console.log("videoM3u8Url:\n" + readData.host + res.items[0].key );
						console.log("videoPic:\n" + readData.host + res.items[1].key );
						process.exit(0);
					}
				});
			});
		},3000);
	}

	(function _updateQueue(count){
			if(count === readData.sources.length){
				if(isUploadFailed){
					console.log("task failed!");
				}else{
					var pfopParams = "";
					//concat video
					if(result.length > 1){
						pfopParams += "avconcat/2/format/mp4";
						for( var i = 1 ; i < result.length ; i++ ){
							pfopParams += ( "/" +  qiniu.util.urlsafeBase64Encode( (  readData.host + result[i].key ) ) );
						}
					pfopParams += "|";
					}
					//watermaker
					pfopParams += ("avthumb/mp4/wmImage/"+ qiniu.util.urlsafeBase64Encode(readData.logoUrl) +"/wmGravity/SouthEast|");

					//hls
					pfopParams += "avthumb/m3u8/segtime/10;";

					//jietu
					pfopParams += "vframe/png/offset/5";

					qiniu.fop.pfop(readData.bucket,result[0].key,pfopParams,{pipeline:"LiveVideoConverter"},function(err,data){
						console.log('persistentId: ' + data.persistentId);
						pullPfopResult(data.persistentId);
					});
				}
				return;
			}
			qiniu.io.putFileWithoutKey(putPolicy.token(),readData.sources[count],{},function(err,data){
				if(err){
					isUploadFailed = true;
					console.log(readData.sources[count] + "   failed");
					process.exit(0);
					return;
				}else{
					result.push(data);
					console.log(readData.sources[count] + "   succeed");
				}
				_updateQueue(++count);
			});
		})(0);
	console.log("enter q to exit!");
	console.log("uploading...");

	process.stdin.setEncoding('utf8');
	process.stdin.resume();
	process.stdin.on('data',function(data){
		data = data.replace("\n","");
		if(data == 'q'){
			process.exit(0);
		}
	});
});


