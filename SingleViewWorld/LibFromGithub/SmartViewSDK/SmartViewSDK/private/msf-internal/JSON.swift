/*

Copyright (c) 2014 Samsung Electronics

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

import Foundation

internal class JSON
{
    class func parse(jsonString: String) -> AnyObject?
    {
        let data: Data = jsonString.data(using: String.Encoding.utf8)!
        return parse(data:data)
    }

    class func parse(data: Data) -> AnyObject?
    {
        do
        {
            let jsonObj: AnyObject = try JSONSerialization.jsonObject( with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject
            return jsonObj
        }
        catch _
        {
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue)!
        }
    }

    class func stringify(_ jsonObject: AnyObject, prettyPrint: Bool = false) -> String?
    {
        let jsonData: Data?
        do
        {
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject,
                        options:  (prettyPrint ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)))
        }
        catch _
        {
            jsonData = nil
        }
        
        if (jsonData == nil)
        {
            return nil
        }
        else
        {
            return  NSString(data: jsonData!, encoding: String.Encoding.utf8.rawValue) as String?
        }
    }

    class func jsonDataForObject(_ jsonObj: AnyObject) -> Data?
    {
        do
        {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObj,options: JSONSerialization.WritingOptions(rawValue: 0))
            return jsonData
        }
        catch _ { }
        
        return nil
    }
    
}
