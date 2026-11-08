using Bozras.Domain.Common;
using Bozras.Domain.Enums;

namespace Bozras.Domain.Entities;

public class Supplier : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }

    public bool IsActive { get; set; } = true;
    public bool RequiresApproval { get; set; }

    public Guid? PlanId { get; set; }
    public Plan? Plan { get; set; }
    public SubscriptionStatus SubscriptionStatus { get; set; } = SubscriptionStatus.Trial;
    public DateTime? SubscriptionEndsAt { get; set; }

    public ICollection<ServiceArea> ServiceAreas { get; set; } = new List<ServiceArea>();
}