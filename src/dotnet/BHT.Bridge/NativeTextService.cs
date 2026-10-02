using System;
using System.Globalization;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
namespace BHT.Bridge
{
    /// <summary>First migrated Lisp service. No CAD command invocation, database writes or TDT dependency.</summary>
    public static class NativeTextService
    {
        [LispFunction("BHTRUNTIMEROOT")]
        public static string RuntimeRoot(ResultBuffer args) { return System.IO.Path.GetDirectoryName(typeof(NativeTextService).Assembly.Location); }
        [LispFunction("BHTSIGNVALIDATE")]
        public static string ValidateSign(ResultBuffer args)
        {
            var values = args == null ? new TypedValue[0] : args.AsArray();
            return SignPresentation.ValidationError(values.Length == 0 ? "" : Convert.ToString(values[0].Value));
        }
        [LispFunction("BHTNATIVESIGNCODE")]
        public static string SignCode(ResultBuffer args)
        {
            string code = "", description = ""; int i = 0;
            if (args != null) foreach (TypedValue item in args) { if(i++ == 0) code = Convert.ToString(item.Value); else description = Convert.ToString(item.Value); }
            return SignPresentation.ResolveCode(code, description) ?? "";
        }
        [LispFunction("BHTNATIVETEXT")]
        public static string ConvertText(ResultBuffer args)
        {
            string operation = "", value = ""; int i = 0;
            if (args != null) foreach (TypedValue item in args) { if (i++ == 0) operation = Convert.ToString(item.Value, CultureInfo.InvariantCulture); else value = Convert.ToString(item.Value, CultureInfo.InvariantCulture); }
            try
            {
                string result;
                switch ((operation ?? "").ToUpperInvariant())
                {
                    case "NFC": result = (value ?? "").Normalize(NormalizationForm.FormC); break;
                    case "ENCODE": result = Tcvn3.Encode(value); break;
                    case "DECODE": result = Tcvn3.Decode(value); break;
                    default: return null;
                }
                return result;
            }
            catch (ArgumentException) { return null; }
        }
    }
}
