"use strict";
function quote_portait_element(item) {
    var ret = document.createElement("div");
    ret.className = "quote_items";
    var port = document.createElement("div");
    port.className = "quote_portrait";
    quote_add_portrait_img(port, item.character, item.alternate, item.hidden);
    var name = document.createElement("p");
    name.className = "portrait_name";
    if (item.character != undefined) {
        let nameplate = item.character;
        nameplate = nameplate[0].toUpperCase() + nameplate.slice(1);
        name.textContent = nameplate;
    }
    if (item.character == undefined || item.known === false) {
        name.textContent = "?";
    }
    name.classList.add(`quote_${item.character}_font`);
    ret.appendChild(name);
    ret.appendChild(port);
    return ret;
}
function quote_add_portrait_img(div, char, alternate, hidden) {
    var base = document.createElement("img");
    var src = "img/";
    if (char != undefined && hidden !== true)
        src += char;
    else
        src += "unknown";
    if (alternate != undefined)
        src += "_" + alternate;
    if (hidden !== true) {
        switch (char) {
            case "canary":
                var pupil = document.createElement("img");
                pupil.src = "img/canary_eyes.png";
                pupil.className = "canary_eyes";
                div.appendChild(pupil);
                break;
            default:
                break;
        }
    }
    base.src = src + ".png";
    div.appendChild(base);
}
