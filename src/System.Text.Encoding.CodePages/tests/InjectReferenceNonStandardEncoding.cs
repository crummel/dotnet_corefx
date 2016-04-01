using System.Text;
using Xunit;

public class InjectReferenceNonStandardEncoding
{
    [Fact]
    public static void GetNonStandardEncoding()
    {
        var windows1252 = Encoding.GetEncoding("windows-1252");
        Assert.Equal("windows-1252", windows1252.WebName);
    }
}