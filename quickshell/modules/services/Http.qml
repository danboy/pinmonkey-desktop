pragma Singleton
import Quickshell
import QtQuick

// Shared XMLHttpRequest helpers so every widget that fetches a public API
// (weather, news, holidays, transit, geolocation) doesn't reimplement this.
Singleton {
    id: root

    function getText(url, callback, errorTag) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.log(errorTag || "http", "request failed", url, xhr.status);
                return;
            }
            callback(xhr.responseText);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function getJson(url, callback, errorTag) {
        root.getText(url, text => {
            try {
                callback(JSON.parse(text));
            } catch (e) {
                console.log(errorTag || "http", "parse error", url, e);
            }
        }, errorTag);
    }
}
