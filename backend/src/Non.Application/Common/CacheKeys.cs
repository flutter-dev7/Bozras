namespace Non.Application.Common;

public static class CacheKeys
{
    public static string ActiveProducts(Guid supplierId) => $"products:{supplierId}:active";

    public static string OrderCutoffTime(Guid supplierId) => $"settings:{supplierId}:order-cutoff-time";

    public static string Product(Guid supplierId, Guid id) => $"products:{supplierId}:{id}";

    public static string OtpCode(string phone) => $"auth:otp:{phone}";

    public static string OtpCooldown(string phone) => $"auth:otp-cooldown:{phone}";

    public static string UserAccess(Guid userId) => $"auth:user-access:{userId}";
}