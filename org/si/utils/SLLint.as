//----------------------------------------------------------------------------------------------------
// Singly linked list of int
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    /** Singly linked list of int. */
    public class SLLint
    {
    // valiables
    //------------------------------------------------------------
        /** int data */
        public var i:int = 0;
        /** Nest pointer of list */
        public var next:SLLint = null;

        // free list
        static private var _freeList:SLLint = null;

        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function SLLint(i:int=0)
        {
            this.i = i;
        }
        
        
        
        
    // allocator
    //------------------------------------------------------------
        /** Allocator */
        static public function alloc(i:int=0) : SLLint
        {
            var ret:SLLint;
            if (_freeList) {
                ret = _freeList;
                _freeList = _freeList.next;
                ret.i = i;
                ret.next = null;
            } else {
                ret = new SLLint(i);
            }
            return ret;
        }
        
        /** Allocator of linked list */
        static public function allocList(size:int) : SLLint
        {
            var ret:SLLint = alloc(),
                elem:SLLint = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc();
                elem = elem.next;
            }
            return ret;
        }
        
        /** Allocator of ring-linked list */
        static public function allocRing(size:int) : SLLint
        {
            var ret:SLLint = alloc(),
                elem:SLLint = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc();
                elem = elem.next;
            }
            elem.next = ret;
            return ret;
        }
        
        /** Ring-linked list with initial values. */
        static public function newRing(...args) : SLLint
        {
            var size:int = args.length,
                ret:SLLint = alloc(args[0]),
                elem:SLLint = ret;
            for (var i:int=1; i<size; i++) {
                elem.next = alloc(args[i]);
                elem = elem.next;
            }
            elem.next = ret;
            return ret;
        }
        
        
        
        
    // deallocator
    //------------------------------------------------------------
        /** Deallocator */
        static public function free(elem:SLLint) : void
        {
            elem.next = _freeList;
            _freeList = elem;
        }
        
        /** Deallocator of linked list */
        static public function freeList(firstElem:SLLint) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLint = firstElem;
            while (lastElem.next) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
        
        /** Deallocator of ring-linked list */
        static public function freeRing(firstElem:SLLint) : void
        {
            if (firstElem == null) return;
            var lastElem:SLLint = firstElem;
            while (lastElem.next == firstElem) { lastElem = lastElem.next; }
            lastElem.next = _freeList;
            _freeList = firstElem;
        }
    }
}

