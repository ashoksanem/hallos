function clear() {
    alert("clearing");
    document.getElementById("halmsg").innerHTML="";
}

function passDataToWeb(message){
    jsonStr = JSON.stringify(message),  // THE OBJECT STRINGIFIED
        regeStr = '', // A EMPTY STRING TO EVENTUALLY HOLD THE FORMATTED STRINGIFIED OBJECT
        f = {
            brace: 0
        };
        var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
        var rtnFn = function() {
            return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
        },
        rtnStr = 0;
        if (p1.lastIndexOf('{') === (p1.length - 1)) {
            rtnStr = rtnFn();
            f['brace'] += 1;
        } else if (p1.indexOf('}') === 0) {
            f['brace'] -= 1;
            rtnStr = rtnFn();
        } else {
            rtnStr = rtnFn();
        }
        return rtnStr;
    });
    document.getElementById("halmsg").innerHTML=regeStr;
}

function sendSSOAuthenticationMessageToWeb(message){
    jsonStr = JSON.stringify(message),
        regeStr = '',
        f = {
            brace: 0
        };
        var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
        var rtnFn = function() {
            return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
        },
        rtnStr = 0;
        if (p1.lastIndexOf('{') === (p1.length - 1)) {
            rtnStr = rtnFn();
            f['brace'] += 1;
        } else if (p1.indexOf('}') === 0) {
            f['brace'] -= 1;
            rtnStr = rtnFn();
        } else {
            rtnStr = rtnFn();
        }
        return rtnStr;
    });
    document.getElementById("SSOMessage").innerHTML=regeStr;
}

function receiveDeviceId(message) {
    document.getElementById("halmsg").innerHTML = "deviceId: " + message.deviceId;
}

function passSSOData(message){
    document.getElementById("halmsg").innerHTML=message;
}

