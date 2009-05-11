//----------------------------------------------------------------------------------------------------
// SiMML data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.sequencer.base.MMLData;
    import org.si.utils.SLLint;
    
    
    
    /** SiMML data class.
     */
    public class SiMMLData extends MMLData
    {
    // valiables
    //----------------------------------------
        /** envelop tables */
        public var envelopTables:Vector.<SiMMLDataEnvelopTable>;
        /** FM channel paramters */
        public var fmParameters:Vector.<SiMMLDataChannelParam>;
        
        
        
    // constructor
    //----------------------------------------
        function SiMMLData()
        {
            envelopTables = new Vector.<SiMMLDataEnvelopTable>();
            fmParameters  = new Vector.<SiMMLDataChannelParam>();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Clear all parameters and free all sequence groups. */
        override public function clear() : void
        {
            super.clear();
            for each (var env:SiMMLDataEnvelopTable in envelopTables) { SiMMLDataEnvelopTable.free(env); }
            for each (var prm:SiMMLDataChannelParam in fmParameters)  { SiMMLDataChannelParam.free(prm); }
            envelopTables.length = 0;
            fmParameters.length = 0;
        }
        
        
        /** Register all tables before processing audio. */
        override public function regiterAllTables() : void
        {
            super.regiterAllTables();
            for each (var env:SiMMLDataEnvelopTable in envelopTables) { env.register(); }
            for each (var prm:SiMMLDataChannelParam in fmParameters)  { prm.register(); }
        }
        
        
        /** @private [internal use] Set envelop table data */
        internal function _setEnvelopTable(index:int, head:SLLint, tail:SLLint) : void
        {
            envelopTables.push(SiMMLDataEnvelopTable.alloc(index, head, tail));
        }
        
        
        /** @private [internal use] Get channel parameter */
        internal function _getSiOPMChannelParam(index:int) : SiOPMChannelParam
        {
            var e:SiMMLDataChannelParam = SiMMLDataChannelParam.alloc(index);
            fmParameters.push(e);
            return e.param;
        }
    }
}




import org.si.sion.module.SiOPMChannelParam;
import org.si.sion.sequencer.SiMMLTable;
import org.si.sion.sequencer.SiMMLEnvelopTable;
import org.si.utils.SLLint;


class SiMMLDataEnvelopTable
{
    public var index:int;
    public var table:SiMMLEnvelopTable;
    static private var _freeList:Array = [];
    
    
    function SiMMLDataEnvelopTable()
    {
        index = -1;
        table = new SiMMLEnvelopTable();
    }
    
    
    public function register() : void
    {
        SiMMLTable.registerEnvelopTable(index, table);
    }
    
    
    static public function free(e:SiMMLDataEnvelopTable) : void
    {
        e.index = -1;
        e.table.free();
        _freeList.push(e);
    }

    
    static public function alloc(index:int, head:SLLint, tail:SLLint) : SiMMLDataEnvelopTable
    { 
        var i:int, imax:int;
        
        // new element
        var e:SiMMLDataEnvelopTable = _freeList.pop() || new SiMMLDataEnvelopTable();

        // initialize
        e.index = index;
        e.table._initialize(head, tail);
        return e;
    }    
}




class SiMMLDataChannelParam
{
    public var index:int;
    public var param:SiOPMChannelParam;
    static private var _freeList:Array = [];
    
    
    function SiMMLDataChannelParam()
    {
        index = -1;
        param = new SiOPMChannelParam();
    }
    
    
    public function register() : void
    {
        SiMMLTable.registerChannelParam(index, param);
    }
    
    
    static public function free(e:SiMMLDataChannelParam) : void
    {
        e.index = -1;
        _freeList.push(e);
    }

    
    static public function alloc(index:int) : SiMMLDataChannelParam
    { 
        var i:int, imax:int;
        
        // new element
        var e:SiMMLDataChannelParam = _freeList.pop() || new SiMMLDataChannelParam();

        // initialize
        e.index = index;
        e.param.initialize();
        return e;
    }    
}

