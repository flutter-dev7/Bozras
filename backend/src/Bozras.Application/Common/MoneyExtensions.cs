using System.Globalization;

namespace Bozras.Application.Common;

public static class MoneyExtensions
{
    public static string ToMoney(this decimal value) => value.ToString("0.##", CultureInfo.InvariantCulture);
}