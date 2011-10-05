String.prototype.startsWith = function(str){
    return this.substr(0, str.length) === str;
};
