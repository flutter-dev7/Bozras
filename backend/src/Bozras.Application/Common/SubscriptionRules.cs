using Bozras.Domain.Enums;

namespace Bozras.Application.Common;

public static class SubscriptionRules
{
    public const int GraceDays = 3;

    public static bool IsAccessAllowed(
        bool isActive, SubscriptionStatus status, DateTime? endsAtUtc, DateTime nowUtc) =>
        isActive
        && status != SubscriptionStatus.Suspended
        && (endsAtUtc is null || endsAtUtc.Value.AddDays(GraceDays) > nowUtc);
}