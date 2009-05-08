//----------------------------------------------------------------------------------------------------
// Translators
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import org.si.sound.module.*;
    
    
    /** Translator */
    public class Translator
    {
        /** constructor */
        function Translator()
        {
        }
        
        
        
        
    // mckc
    //--------------------------------------------------
        /** Translate ppmckc mml to SiOPM mml. */
        static public function mckc(mckcMML:String) : String
        {
            // If I have motivation ..., or I wish someone who know mck well would do ...
            return mckcMML;
        }
        
        
        
        
    // tsscp
    //--------------------------------------------------
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
            var p0:int, p1:int, p2:int, p3:int, p4:int, reql8:Boolean, octave:int, revOct:Boolean, 
                loopOct:int, loopMacro:Boolean, loopMMLBefore:String, loopMMLContent:String;

            rex  = new RegExp("(;|(/:|:/|ml|mp|na|ns|nt|ph|@kr|@ks|@ml|@ns|@apn|@[fkimopqsv]?|[klopqrstvx$%<>(){}[\\]|_~^/&*]|[a-g][#+\\-]?)\\s*([\\-\\d]*)[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?)|#(FM|[A-Z]+)=?\\s*([^;]*)|([A-Z])(\\(([a-g])([\\-+#]?)\\))?|.", "gms");
            rex_sys = /\s*([0-9]*)[,=<\s]*([^>]*)/ms;
            rex_com = /[{}]/gms;

            volUp = "(";
            volDw = ")";
            mml = "";
            reql8 = true;
            octave = 5;
            revOct = false;
            loopOct = -1;
            loopMacro = false;
            loopMMLBefore = undefined;
            loopMMLContent = undefined;
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
                                case 'o':   { mml += res[0]; octave = int(res[3]); }break;
                                case '<':   { mml += res[0]; octave += (revOct) ? -1 :  1; }break;
                                case '>':   { mml += res[0]; octave += (revOct) ?  1 : -1; }break;
                                case '%':   { mml += (res[3] == '6') ? '%4' : res[0]; }break;
                                
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
                                            if (res == null) throw errorTranslation("{{...} ?");
                                        if (res[0] == '{') i++;
                                        else if (res[0] == '}') --i;
                                    } while (i);
                                    mml += "/*{" + tsscpMML.substring(p0, res.index) + "}*/";
                                    rex.lastIndex = res.index + 1;
                                }break;
                                    
                                case '[': { 
                                    if (loopMMLBefore) errorTranslation("[[...] ?");
                                    loopMacro = false;
                                    loopMMLBefore = mml;
                                    loopMMLContent = undefined;
                                    mml = res[3];
                                    loopOct = octave;
                                }break;
                                case '|': {
                                    if (!loopMMLBefore) errorTranslation("'|' can be only in '[...]'");
                                    loopMMLContent = mml; 
                                    mml = "";
                                }break;
                                case ']': {
                                    if (!loopMMLBefore) errorTranslation("[...]] ?");
                                    if (!loopMacro && loopOct==octave) {
                                        if (loopMMLContent)  mml = loopMMLBefore + "[" + loopMMLContent + "|" + mml + "]";
                                        else                 mml = loopMMLBefore + "[" + mml + "]";
                                    } else {
                                        if (loopMMLContent)  mml = loopMMLBefore + "![" + loopMMLContent + "!|" + mml + "!]";
                                        else                 mml = loopMMLBefore + "![" + mml + "!]";
                                    }
                                    loopMMLBefore = undefined;
                                    loopMMLContent = undefined;
                                }break;

                                case '}': 
                                    throw errorTranslation("{...}} ?");
                                case '@apn': case 'x':
                                    break;
                                
                                default: {
                                    mml += res[0];
                                }break;
                            }
                        }
                    }
                } else 
                
                if (res[10] != undefined) {
                    // macro expansion
                    if (reql8) mml += "l8" + res[10];
                    else       mml += res[10];
                    reql8 = false;
                    loopMacro = true;
                    if (res[11] != undefined) {
                        // note shift
                        i = noteShift[noteLetters.indexOf(res[12])];
                        if (res[13] == '+' || res[13] == '#') i++;
                        else if (res[13] == '-') i--;
                        mml += "(" + String(i) + ")";
                    }
                } else 
                
                if (res[8] != undefined) {
                    // system command
                    str1 = res[8];
                    switch (str1) {
                        case 'END':    { mml += "#END"; }break;
                        case 'OCTAVE': { 
                            if (res[9] == 'REVERSE') {
                                mml += "#REV{octave}"; 
                                revOct = true;
                            }
                        }break;
                        case 'OCTAVEREVERSE': { 
                            mml += "#REV{octave}"; 
                            revOct = true;
                        }break;
                        case 'VOLUME': {
                            if (res[9] == 'REVERSE') {
                                volUp = ")";
                                volDw = "(";
                                mml += "#REV{volume}";
                            }
                        }break;
                        case 'VOLUMEREVERSE': {
                            volUp = ")";
                            volDw = "(";
                            mml += "#REV{volume}";
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
                            mml += "#FM{" + String(res[9]).replace(/([A-Z])([0-9])?(\()?/g, 
                                function() : String {
                                    var num:int = (arguments[2]) ? (int(arguments[2])) : 3;
                                    var str:String = (arguments[3]) ? (String(num) + "(") : "";
                                    return String(arguments[1]).toLowerCase() + str;
                                }
                            ) + "}" ;//))
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
                
                {
                    mml += res[0];
                }
                res = rex.exec(tsscpMML);
            }
            tsscpMML = mml;
            
            return tsscpMML;
        }
        

        
        
    // mml256 (still in concept)
    //--------------------------------------------------
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
        
        
        
        
    // FM parameters
    //--------------------------------------------------
        /** #@{..};
         *  alg[0-15], fb[0-7], fbc[0-3], 
         *  (ws[0-1023], ar[0-63], dr[0-63], sr[0-63], rr[0-63], sl[0-15], tl[0-127], ksr[0-3], ksl[0-3], mul[], dt1[0-7], detune[], ams[0-3], phase[-1-255], fixedNote[0-127]) x operator_count
         */
        static public function parseParam(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 3, 15, "#@");
            if (param.opeCount == 0) return;
            
            param.alg = int(data[0]);
            param.fb  = int(data[1]);
            param.fbc = int(data[2]);
            var dataIndex:int = 3, n:Number, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.setPGType(int(data[dataIndex++]) & 1023); // 1
                opp.ar     = int(data[dataIndex++]) & 63;   // 2
                opp.dr     = int(data[dataIndex++]) & 63;   // 3
                opp.sr     = int(data[dataIndex++]) & 63;   // 4
                opp.rr     = int(data[dataIndex++]) & 63;   // 5
                opp.sl     = int(data[dataIndex++]) & 15;   // 6
                opp.tl     = int(data[dataIndex++]) & 127;  // 7
                opp.ksr    = int(data[dataIndex++]) & 3;    // 8
                opp.ksl    = int(data[dataIndex++]) & 3;    // 9
                n = Number(data[dataIndex++]);
                opp.fmul   = (n==0) ? 64 : int(n*128);      // 10
                opp.dt1    = int(data[dataIndex++]) & 7;    // 11
                opp.detune = int(data[dataIndex++]);        // 12
                opp.ams    = int(data[dataIndex++]) & 3;    // 13
                i = int(data[dataIndex++]);
                opp.phase  = (i==-1) ? i : (i & 255);           // 14
                opp.fixedPitch = (int(data[dataIndex++]) & 127)<<6;  // 15
            }
        }
        
        
        /** #OPL@{..};
         *  alg[0-15], fb[0-7], 
         *  (ws[0-7], ar[0-15], dr[0-15], rr[0-15], egt[0,1], sl[0-15], tl[0-63], ksr[0,1], ksl[0-3], mul[0-15], ams[0-3]) x operator_count
         */
        static public function parseOPLParam(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 2, 11, "#OPL@");
            if (param.opeCount == 0) return;
            
            var alg:int = SiMMLTable.instance.alg_opl[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPL@ algorism", data[0]);
            
            param.fratio = 133;
            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.setPGType(SiOPMTable.PG_MA3_WAVE + (int(data[dataIndex++])&31));    // 1
                opp.ar  = (int(data[dataIndex++]) << 2) & 63;   // 2
                opp.dr  = (int(data[dataIndex++]) << 2) & 63;   // 3
                opp.rr  = (int(data[dataIndex++]) << 2) & 63;   // 4
                // egt=0;decay tone / egt=1;holding tone           5
                opp.sr  = (int(data[dataIndex++]) != 0) ? 0 : opp.rr;
                opp.sl  = int(data[dataIndex++]) & 15;          // 6
                opp.tl  = int(data[dataIndex++]) & 63;          // 7
                opp.ksr = (int(data[dataIndex++])<<1) & 3;      // 8
                opp.ksl = int(data[dataIndex++]) & 3;           // 9
                i = int(data[dataIndex++]) & 15;                // 10
                opp.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
                opp.ams = int(data[dataIndex++]) & 3;           // 11
                // multiple
            }
        }
        
        
        /** #OPM@{..};
         *  alg[0-15], fb[0-7], 
         *  (ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], dt2[0-3], ams[0-3]) x operator_count
         */
        static public function parseOPMParam(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 2, 11, "#OPM@");
            if (param.opeCount == 0) return;
            
            var alg:int = SiMMLTable.instance.alg_opm[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPN@ algorism", data[0]);

            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 1
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 4
                opp.sl  = int(data[dataIndex++]) & 15;              // 5
                opp.tl  = int(data[dataIndex++]) & 127;             // 6
                opp.ksr = int(data[dataIndex++]) & 3;               // 7
                opp.mul = int(data[dataIndex++]) & 15;              // 8
                opp.dt1 = int(data[dataIndex++]) & 7;               // 9
                opp.detune = SiOPMTable.instance.dt2Table[data[dataIndex++] & 3];    // 10
                opp.ams = int(data[dataIndex++]) & 3;               // 11
            }
        }
        
        
        /** #OPN@{..};
         *  alg[0-15], fb[0-7], 
         *  (ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], ams[0-3]) x operator_count
         */
        static public function parseOPNParam(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 2, 10, "#OPN@");
            if (param.opeCount == 0) return;
            
            var alg:int = SiMMLTable.instance.alg_opm[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPN@ algorism", data[0]);

            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 1
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 4
                opp.sl  = int(data[dataIndex++]) & 15;              // 5
                opp.tl  = int(data[dataIndex++]) & 127;             // 6
                opp.ksr = int(data[dataIndex++]) & 3;               // 7
                opp.mul = int(data[dataIndex++]) & 15;              // 8
                opp.dt1 = int(data[dataIndex++]) & 7;               // 9
                opp.ams = int(data[dataIndex++]) & 3;               // 10
            }
        }
        
        
        /** #OPX@{..};
         *  alg[0-15], fb[0-7], 
         *  (ws[0-7], ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], detune[], ams[0-3]) x operator_count
         */
        static public function parseOPXParam(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 2, 12, "#OPX@");
            if (param.opeCount == 0) return;
            
            var alg:int = SiMMLTable.instance.alg_opx[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPX@ algorism", data[0]);
            
            param.alg = (alg & 15);
            param.fb  = int(data[1]);
            param.fbc = (alg & 16) ? 1 : 0;
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                i = int(data[dataIndex++]);
                opp.setPGType((i<7) ? (SiOPMTable.PG_MA3_WAVE+(i&7)) : (SiOPMTable.PG_CUSTOM+(i-7)));    // 1
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 4
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 5
                opp.sl  = int(data[dataIndex++]) & 15;              // 6
                opp.tl  = int(data[dataIndex++]) & 127;             // 7
                opp.ksr = int(data[dataIndex++]) & 3;               // 8
                opp.mul = int(data[dataIndex++]) & 15;              // 9
                opp.dt1 = int(data[dataIndex++]) & 7;               // 10
                opp.detune = int(data[dataIndex++]);                // 11
                opp.ams = int(data[dataIndex++]) & 3;               // 12
            }
        }
        
        
        /** #MA@{..};
         *  alg[0-15], fb[0-7], 
         *  (ws[0-31], ar[0-15], dr[0-15], sr[0-15], rr[0-15], sl[0-15], tl[0-63], ksr[0,1], ksl[0-3], mul[0-15], dt1[0-7], ams[0-3]) x operator_count
         */
        static public function parseMA3Param(param:SiOPMChannelParam, dataString:String) : void
        {
            var data:Array = _splitDataString(param, dataString, 2, 12, "#MA@");
            if (param.opeCount == 0) return;
            
            var alg:int = SiMMLTable.instance.alg_ma3[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#MA@ algorism", data[0]);
            
            param.fratio = 133;
            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.setPGType(SiOPMTable.PG_MA3_WAVE + (int(data[dataIndex++]) & 31)); // 1
                opp.ar  = (int(data[dataIndex++]) << 2) & 63;   // 2
                opp.dr  = (int(data[dataIndex++]) << 2) & 63;   // 3
                opp.sr  = (int(data[dataIndex++]) << 2) & 63;   // 4
                opp.rr  = (int(data[dataIndex++]) << 2) & 63;   // 5
                opp.sl  = int(data[dataIndex++]) & 15;          // 6
                opp.tl  = int(data[dataIndex++]) & 63;          // 7
                opp.ksr = (int(data[dataIndex++])<<1) & 3;      // 8
                opp.ksl = int(data[dataIndex++]) & 3;           // 9
                i = int(data[dataIndex++]) & 15;                // 10
                opp.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
                opp.dt1 = int(data[dataIndex++]) & 7;           // 11
                opp.ams = int(data[dataIndex++]) & 3;           // 12
            }
        }
        

        // split dataString of #@ macro
        static private function _splitDataString(param:SiOPMChannelParam, dataString:String, chParamCount:int, opParamCount:int, cmd:String) : Array
        {
            var data:Array, i:int;
            
            // parse parameters
            if (dataString == "") {
                param.opeCount = 0;
            } else {
                data = dataString.replace(/^[^\d\-.]+|[^\d\-.]+$/g, "").split(/[^\d\-.]+/gm);
                for (i=1; i<5; i++) {
                    if (data.length == chParamCount + opParamCount*i) {
                        param.opeCount = i;
                        return data;
                    }
                }
                throw errorToneParameterNotValid(cmd, chParamCount, opParamCount);
            }
            return null;
        }
        
        
        /** Set parameters by Array data. */
        static public function setParam(param:SiOPMChannelParam, data:Array) : void
        {
            param.opeCount = int((data.length - 3) / 15);
            param.alg = int(data[0]);
            param.fb  = int(data[1]);
            param.fbc = int(data[2]);
            
            var dataIndex:int = 3, n:Number, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.opeParam[opeIndex];
                opp.setPGType(int(data[dataIndex++]) & 1023); // 1
                opp.ar     = int(data[dataIndex++]) & 63;   // 2
                opp.dr     = int(data[dataIndex++]) & 63;   // 3
                opp.sr     = int(data[dataIndex++]) & 63;   // 4
                opp.rr     = int(data[dataIndex++]) & 63;   // 5
                opp.sl     = int(data[dataIndex++]) & 15;   // 6
                opp.tl     = int(data[dataIndex++]) & 127;  // 7
                opp.ksr    = int(data[dataIndex++]) & 3;    // 8
                opp.ksl    = int(data[dataIndex++]) & 3;    // 9
                n = Number(data[dataIndex++]);
                opp.fmul   = (n==0) ? 64 : int(n*128);      // 10
                opp.dt1    = int(data[dataIndex++]) & 7;    // 11
                opp.detune = int(data[dataIndex++]);        // 12
                opp.ams    = int(data[dataIndex++]) & 3;    // 13
                i = int(data[dataIndex++]);
                opp.phase  = (i==-1) ? i : (i & 255);           // 14
                opp.fixedPitch = (int(data[dataIndex++]) & 127)<<6;  // 15
            }
        }
        
        
        
        
        
        
    // errors
    //--------------------------------------------------
        static public function errorToneParameterNotValid(cmd:String, chParam:int, opParam:int) : Error
        {
            return new Error("Translator error : Parameter count is not valid in '" + cmd + "'. " + String(chParam) + " parameters for channel and " + String(opParam) + " parameters for each operator.");
        }
        
        static public function errorParameterNotValid(cmd:String, param:String) : Error
        {
            return new Error("Translator error : Parameter not valid. '" + param + "' in " + cmd);
        }
        
        static public function errorTranslation(str:String) : Error
        {
            return new Error("Translator Error : mml error. '" + str + "'");
        }
    }
}

