/***************************************************************************************************
The MIT License (MIT)

Copyright 2020 Daiki Sakamoto

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or 
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************************************/
using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Linq;

namespace BUILDLet.PowerShell.Utilities
{
    public static class SessionLocation
    {
        // ----------------------------------------------------------------------------------------------------
        // Static Method(s)
        // ----------------------------------------------------------------------------------------------------

        // GET Unresolved Path
        public static string GetUnresolvedPath(SessionState session, string path) =>
            Path.GetFullPath(Path.IsPathRooted(path) ? path : Path.Combine(session.Path.CurrentFileSystemLocation.Path, session.Path.GetUnresolvedProviderPathFromPSPath(path)));

        // GET Resolved Path
        public static string[] GetResolvedPath(SessionState session, string path) => (
            from resolved_path in session.Path.GetResolvedProviderPathFromPSPath(path, out _)
            select Path.GetFullPath(Path.IsPathRooted(resolved_path) ? resolved_path : Path.Combine(session.Path.CurrentFileSystemLocation.Path, resolved_path))
            ).ToArray();
    }
}
