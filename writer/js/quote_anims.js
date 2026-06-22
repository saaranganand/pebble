"use strict";
function shakeText(element) {
    var _a;
    if (!element)
        return;
    if (element.style.getPropertyValue('--shaken').trim() === 'true')
        return;
    element.style.setProperty('--shaken', 'true');
    let parent_size = element.style.getPropertyValue('--size').trim();
    let base = 0.3;
    console.log(parseInt(element.style.fontSize));
    if (parseInt(element.style.fontSize) < 32) {
        base = 0.1;
    }
    const nodes = Array.from(element.childNodes);
    for (const node of nodes) {
        if (node.nodeType === Node.TEXT_NODE) {
            // Split raw text into individual letter spans
            const fragment = document.createDocumentFragment();
            console.log(base);
            for (const char of (_a = node.textContent) !== null && _a !== void 0 ? _a : '') {
                let xneg = Math.round(Math.random()) == 1 ? -1 : 1;
                let yneg = Math.round(Math.random()) == 1 ? -1 : 1;
                const span = document.createElement('span');
                span.className = 'shake_letter';
                span.style.setProperty('--delay', `${(Math.random() * 0.3).toFixed(2)}s`);
                span.style.setProperty('--duration', `${(0.1).toFixed(2)}s`);
                span.style.setProperty('--xdist', `${(xneg * (base + Math.random() * 0.1)).toFixed(1)}px`);
                span.style.setProperty('--ydist', `${(yneg * (base + Math.random() * 0.1)).toFixed(1)}px`);
                // we have to copy over the size variable, since the .quote -> pre -> span style
                // uses the size variable, and defaults it to 1
                // so even though the parent aka creator uses a size,
                // the child wont inherit
                span.style.setProperty('--size', parent_size);
                span.textContent = char === ' ' ? '\u00a0' : char;
                fragment.appendChild(span);
            }
            node.replaceWith(fragment);
        }
        else if (node.nodeType === Node.ELEMENT_NODE) {
            // Recurse into existing elements (e.g. <span style="color:red">)
            shakeText(node);
        }
    }
}
function call_anims() {
    let shake_eles = document.querySelectorAll('.shake');
    for (const ele of shake_eles)
        shakeText(ele);
}
