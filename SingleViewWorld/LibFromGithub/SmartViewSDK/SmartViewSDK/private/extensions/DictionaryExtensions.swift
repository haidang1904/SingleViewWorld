//
//  DictionaryExtensions.swift
//  MSF
//
//  Created by Eugene Kolpakov on 12/2/15.
//  Copyright © 2015 Samsung. All rights reserved.
//

import Foundation

func += <KeyType, ValueType> (left: inout [KeyType:ValueType], right: [KeyType:ValueType])
{
    for (k, v) in right
    {
        left.updateValue(v, forKey: k)
    } 
}
