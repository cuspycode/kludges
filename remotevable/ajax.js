var url = "/cgi-bin/removable/request.pl";
var davRoot = "/removable/";
var labelMap = {'mount': "Mount", 'unmount': "Unmount"};
var opMap = {'mounted': "unmount", 'unmounted': "mount"};

function createButton(op, volid) {
    var button = document.createElement("input");
    button.setAttribute("type", "button");
    button.setAttribute("value", labelMap[op]);
    button.onclick = function() { doop(op, volid); return false; };
    return button;
}

function createListItem(op, name) {
    var li = document.createElement("li");
    var txt = document.createTextNode(name);
    if (op == 'mounted') {
	var a = document.createElement("a");
	a.setAttribute("href", davRoot + encodeURIComponent(name));
	a.appendChild(txt);
	li.appendChild(a);
    } else {
	li.appendChild(txt);
    }
    li.appendChild(document.createTextNode('\u00a0'));
    li.appendChild(createButton(opMap[op], name));
    return li;
}

function getVolumeList(type) {
    var http = new XMLHttpRequest();
    var params = "op=list&volid=" + type;
    http.open("POST", url, true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.setRequestHeader("Content-length", params.length);
    http.setRequestHeader("Connection", "close");

    http.onreadystatechange = function() {
	if(http.readyState == 4 && http.status == 200) {
	    var list = http.responseXML.documentElement.getElementsByTagName("volume");
	    var html = document.getElementById("volumes-" + type);
	    for (var i=0; i<list.length; i++) {
		html.appendChild(createListItem(type, list[i].firstChild.nodeValue));
	    }
	}
    }

    http.send(params);
}

function doop(op, volid) {
    var http = new XMLHttpRequest();
    var params = "op=" + op + "&volid=" + encodeURIComponent(volid);
    http.open("POST", url, true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.setRequestHeader("Content-length", params.length);
    http.setRequestHeader("Connection", "close");

    http.onreadystatechange = function() {
	if(http.readyState == 4 && http.status == 200) {
	    //var list = http.responseXML.documentElement.getElementsByTagName("ok");
	    refresh();
	}
    }
    http.send(params);
}

function removeAllChildren(node) {
    while (node.hasChildNodes()) { node.removeChild(node.firstChild); }
}

function refresh() {
    removeAllChildren(document.getElementById("volumes-mounted"));
    removeAllChildren(document.getElementById("volumes-unmounted"));

    getVolumeList("mounted");
    getVolumeList("unmounted");
}

