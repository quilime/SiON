//----------------------------------------------------------------------------------------------------
// Translators
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.driver {
    /** Translator */
    public class Translator
    {
        /** constructor */
        function Translator()
        {
        }
        
        
        
        
        /** Translate pTSSCP mml to SiOPM mml. */
        static public function tsscp(tsscpMML:String) : String
        {
            var mml:String, com:String, str1:String, str2:String, i:int, imax:int, volUp:String, volDw:String, rex:RegExp, rex_sys:RegExp, rex_com:RegExp, res:*;
            
        // translate mml
        //--------------------------------------------------
            var noteLetters:String = "cdefgab";
            var noteShift:Array  = [0,2,4,5,7,9,11];
            var panTable:Array = ["@v0","p0","p8","p4"];
            var table:SiMMLTable = SiMMLTable.instance;
            var charCodeA:int = "a".charCodeAt(0);
            var charCodeG:int = "g".charCodeAt(0);
            var charCodeR:int = "r".charCodeAt(0);
            var hex:String = "0123456789abcdef";
            var p0:int, p1:int, p2:int, p3:int, p4:int, reql8:Boolean;

            rex  = new RegExp("(;|(/:|:/|ml|mp|na|ns|nt|ph|@kr|@ks|@ml|@ns|@apn|@[fkimopqsv]?|[klopqrstvx$%<>(){}[\\]|_~^/&*]|[a-g][#+\\-]?)\\s*([\\-\\d]*)[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?)|#(FM|[A-Z]+)=?\\s*([^;]*)|([A-Z])(\\(([a-g])([\\-+#]?)\\))?|.", "gms");
            rex_sys = /\s*([0-9]*)[,=<\s]*([^>]*)/ms;
            rex_com = /[{}]/gms;

            volUp = "(";
            volDw = ")";
            mml = "";
            reql8 = true;
            res = rex.exec(tsscpMML);
            while (res) {
                if (res[1] != undefined) {
                    if (res[1] == ';') {
                        mml += res[0];
                        reql8 = true;
                    } else {
                        // mml commands
                        i = res[2].charCodeAt(0);
                        if ((charCodeA <= i && i <= charCodeG) || i == charCodeR) {
                            if (reql8) mml += "l8" + res[0];
                            else       mml += res[0];
                            reql8 = false;
                        } else {
                            switch (res[2]) {
                                case 'l':   { mml += res[0]; reql8 = false; }break;
                                case '/:':  { mml += "[" + res[3]; }break;
                                case ':/':  { mml += "]"; }break;
                                case '/':   { mml += "|"; }break;
                                case '[':   { mml += "![" + res[3]; }break;
                                case ']':   { mml += "!]"; }break;
                                case '|':   { mml += "!|"; }break;
                                case '~':   { mml += volUp + res[3]; }break;
                                case '_':   { mml += volDw + res[3]; }break;
                                case 'q':   { mml += "q" + String((int(res[3])+1)>>1); }break;
                                case '@m':  { mml += "@mask" + String(int(res[3])); }break;
                                case 'ml':  { mml += "@ml" + String(int(res[3])); }break;
                                case 'p':   { mml += panTable[int(res[3])&3]; }break;
                                case '@p':  { mml += "@p" + String(int(res[3])-64); }break;
                                case 'ph':  { mml += "@ph" + String(int(res[3])); }break;
                                case 'ns':  { mml += "kt"  + res[3]; }break;
                                case '@ns': { mml += "!@ns" + res[3]; }break;
                                case 'k':   { p0 = Number(res[3]) * 4;     mml += "k"  + String(p0); }break;
                                case '@k':  { p0 = Number(res[3]) * 0.768; mml += "k"  + String(p0); }break;
                                case '@kr': { p0 = Number(res[3]) * 0.768; mml += "!@kr" + String(p0); }break;
                                case '@ks': { mml += "@,,,,,,," + String(int(res[3]) >> 5); }break;
                                case 'na':  { mml += "!" + res[0]; }break;
                                case '%':   {
                                    mml += (res[3] == '6') ? '%4' : res[0];
                                }break;
                                case '@ml': { 
                                    p0 = int(res[3])>>7;
                                    p1 = int(res[3]) - (p0<<7);
                                    mml += "@ml" + String(p0) + "," + String(p1);
                                }break;
                                case 'mp': {
                                    p0 = int(res[3]); p1 = int(res[4]); p2 = int(res[5]); p3 = int(res[6]); p4 = int(res[7]);
                                    if (p3 == 0) p3 = 1;
                                    switch(p0) {
                                    case 0:  mml += "mp0"; break;
                                    case 1:  mml += "@lfo" + String((int(p1/p3)+1)*4*p2) + "mp" + String(p1);   break;
                                    default: mml += "@lfo" + String((int(p1/p3)+1)*4*p2) + "mp0," + String(p1) + "," + String(p0);   break;
                                    }
                                }break;
                                case 'v': {
                                    p0 = (res[3].length == 0) ? 40 : ((int(res[3])<<2)+(int(res[3])>>2));
                                    if (res[4]) {
                                        p1 = (int(res[4])<<2) + (int(res[4])>>2);
                                        p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                        p3 = (p0 > p1) ? p0 : p1;
                                        mml += "@p" + String(p2) + "x" + String(p3);
                                    } else {
                                        mml += "x" + String(p0);
                                    }
                                }break;
                                case '@v': {
                                    p0 = (res[3].length == 0) ? 40 : (int(res[3])>>2);
                                    if (res[4]) {
                                        p1 = int(res[4])>>2;
                                        p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                        p3 = (p0 > p1) ? p0 : p1;
                                        mml += "@p" + String(p2) + "x" + String(p3);
                                    } else {
                                        mml += "x" + String(p0);
                                    }
                                }break;
                                case 's': {
                                    p0 = int(res[3]); p1 = int(res[4]);
                                    mml += "s" + table.tss_s2rr[p0&255];
                                    if (p1!=0) mml += ","  + String(p1*3);
                                }break;
                                case '@s': {
                                    p0 = int(res[3]); p1 = int(res[4]); p3 = int(res[6]);
                                    p2 = (int(res[5]) >= 100) ? 15 : int(Number(res[5])*0.09);
                                    mml += (p0 == 0) ? "@,63,0,0,,0" : (
                                        "@," + table.tss_s2ar[p0&255] + ","  + table.tss_s2dr[p1&255] + "," + table.tss_s2sr[p3&255] + ",," + String(p2)
                                    );
                                }break;
                                case '{': {
                                    i = 1;
                                    p0 = res.index + 1;
                                    rex_com.lastIndex = p0;
                                    do {
                                        res = rex_com.exec(tsscpMML);
                                        if (res == null) throw errorTranslation("too many {s");
                                        if (res[0] == '{') i++;
                                        else if (res[0] == '}') --i;
                                    } while (i);
                                    mml += "/*{" + tsscpMML.substring(p0, res.index) + "}*/";
                                    rex.lastIndex = res.index + 1;
                                }break;
                                    
                                case '}': 
                                    throw errorTranslation("too many }s");
                                case '@apn': case 'x':
                                    break;
                                
                                default: {
                                    mml += res[0];
                                }break;
                            }
                        }
                    }
                } else 
                
                if (res[8] != undefined) {
                    // macro definition
                    str1 = res[8];
                    switch (str1) {
                        case 'END':    { mml += "#END"; }break;
                        case 'OCTAVE': { if (res[9] == 'REVERSE') mml += "#REVo"; }break;
                        case 'OCTAVEREVERSE': { mml += "#REVo"; }break;
                        case 'VOLUME': {
                            if (res[9] == 'REVERSE') {
                                volUp = ")";
                                volDw = "(";
                                mml += "#REVv";
                            }
                        }break;
                        case 'VOLUMEREVERSE': {
                            volUp = ")";
                            volDw = "(";
                            mml += "#REVv";
                        }break;
                        
                        case 'TABLE': {
                            res = rex_sys.exec(res[9]);
                            mml += "#TABLE" + res[1] + "{" + res[2] + "}*0.25";
                        }break;
                        
                        case 'WAVB': {
                            res = rex_sys.exec(res[9]);
                            str1 = String(res[2]);
                            mml += "#WAVB" + res[1] + "{";
                            for (i=0; i<32; i++) {
                                p0 = int("0x" + str1.substr(i<<1, 2));
                                p0 = (p0<128) ? (p0+127) : (p0-128);
                                mml += hex.charAt(p0>>4) + hex.charAt(p0&15);
                            }
                            mml += "}";
                        }break;
                        
                        case 'FM': {
                            mml += "#FM" + String(res[9]).replace(/([A-Z])([0-9])?(\()?/g, 
                                function() : String {
                                    var num:int = (arguments[2]) ? (int(arguments[2])) : 3;
                                    var str:String = (arguments[3]) ? (String(num) + "(") : "";
                                    return String(arguments[1]).toLowerCase() + str;
                                }
                            );//))
                        }break;
                        
                        case 'FINENESS':
                        case 'MML':
                            // skip next ";"
                            res = rex.exec(tsscpMML);
                            break;
                        default: {
                            if (str1.length == 1) {
                                // macro
                                mml += "#" + str1 + "=";
                                rex.lastIndex -= res[9].length;
                                reql8 = false;
                            } else {
                                // other system events
                                res = rex_sys.exec(res[9]);
                                if (res[2].length == 0) return "#" + str1 + res[1];
                                mml += "#" + str1 + res[1] + "{" + res[2] + "}";
                            }
                        }break;
                    }
                } else 
                
                if (res[10] != undefined) {
                    // macro expansion
                    if (reql8) mml += "l8" + res[10];
                    else       mml += res[10];
                    reql8 = false;
                    if (res[11] != undefined) {
                        // note shift
                        i = noteShift[noteLetters.indexOf(res[12])];
                        if (res[13] == '+' || res[13] == '#') i++;
                        else if (res[13] == '-') i--;
                        mml += "(" + String(i) + ")";
                    }
                } else 
                {
                    mml += res[0];
                }
                res = rex.exec(tsscpMML);
            }
            tsscpMML = mml;
            
            return tsscpMML;
        }
        

        
        
        /** Translate mml256 to SiOPM mml. */
        static public function mml256(org:String) : String
        {
            var rex:RegExp, res:*, mml:String, i:int, seqStart:Boolean, track:int;
            var det:Array = ["-15",  "-7", "-3", "-1",  "0",  "1",  "3",  "7", "15", "0"];
            var ar:Array  = [ "63",  "52", "46", "40", "36", "32", "28", "24", "20", "16"];
            var dr:Array  = [ "63",  "52", "46", "40", "36", "32", "28", "24", "20", "16"];
            var sr:Array  = [ "63",  "52", "46", "40", "36", "32", "28", "24", "20", "16"];
            var rr:Array  = [ "63",  "44", "36", "32", "28", "24", "20", "16", "12",  "8"];
            var sw:Array  = ["-48", "-20", "-8", "-2",  "0",  "2",  "8", "20", "48", "0"];
            var mod:Array = [  "0",   "1",  "4",  "5",  "8", "18", "20", "22",  "3", "10"];
            var trk:Array = [  "5",   "5",  "3",  "8"];
            var ccA:int = "A".charCodeAt(0),
                ccZ:int = "Z".charCodeAt(0);
            
            rex = /([A-Z])=([^;]*)|([a-zA-Z|\[\]()<>@$;])([0-9]*)/gms;
            mml = "";
            seqStart = true;
            track = 0;
            
            res = rex.exec(org);
            while (res) {
                if (res[1]) {
                    mml += "#" + res[1] + "=" + res[2] + ";";
                } else {
                    if (seqStart) {
                        if (track > 4) mml += "l8%5@5"
                        else mml += "l8%5@" + trk[track];
                        seqStart = false;
                        track++;
                    }
                    switch(res[3]) {
                        case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': 
                        case 'l': case 'o': case 'p': case 'q': case 'r': case 't': 
                        case '<': case '>': case '(': case ')': case '$':{
                            mml += res[3] + res[4];
                        }break;
                        case ';': { mml += ";"; seqStart = true; }break;
                        case 'k': { mml += "k" + det[_p(0,4)]; }break;
                        case 'n': {
                            mml += "@,," + ar[_p(0,0)];
                            mml += "," + ((res[4].length > 1) ? dr[_p(1,0)] : "");
                            mml += "," + ((res[4].length > 3) ? sr[_p(3,0)] : "");
                            mml += "," + ((res[4].length > 4) ? rr[_p(4,0)] : "");
                            mml += "," + ((res[4].length > 2) ? String(_p(2,0)) : "");
                            if (res[4].length > 5) mml += "@rr," + sw[_p(5,4)];
                        }break;
                        case 's': { mml += "@rr" + rr[_p(0,0)] + "," + sw[_p(1,4)]; }break;
                        case '@': {
                            mml += "@" + mod[_p(0,3)];
                            if (res[4].length > 1) mml += "v" + String(int(_p(1,8)*2));
                            if (res[4].length > 2) mml += "q" + String(int(_p(2,6)));
                            if (res[4].length > 3) mml += "@rr" + rr[_p(3,0)] + "," + sw[_p(4,4)];
                        }break;
                        case 'v': { 
                            mml += "p" + String(int(_p(1,4)));
                            mml += "v" + String(int(_p(0,8)*2));
                        }break;
                        case 'm': {
                            switch (res[4].length) {
                                case 0: case 1: { 
                                    mml += "mp" + String(int(_p(0,0)*3));
                                }break;
                                default: { 
                                    mml += "mp0,";
                                    mml += String(int(_p(0,0)*3)) + ",";
                                    mml += String(int(_p(1,0)*4)) + ",";
                                    mml += String(int(_p(2,0)*4));
                                }break;
                            }
                        }break;
                        default: {
                            if (res[3].charCodeAt(0) >= ccA && res[3].charCodeAt(0) <= ccZ) {
                                if (res[4].length>0) mml += res[3] + "(" + res[4] + ")";
                                else                 mml += res[3];
                            } else {
                                throw errorTranslation(res[3]+res[4]);
                            }
                        }
                    }

                }
                res = rex.exec(org);
            }
            
            function _p(index:int, defaultValue:int) : int {
                if (index >= res[4].length) return defaultValue;
                return int(res[4].charAt(index));
            }
            
            return mml;
        }
        
        
    
        
        static public function errorTranslation(str:String) : Error
        {
            return new Error("SiOPMTranslator Error : mml error. '" + str + "'");
        }
    }
}

