using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class Visit : BaseEntity, ITenantEntity
{
    public Guid ShopId { get; set; }
    public Shop? Shop { get; set; }

    public Guid AgentId { get; set; }
    public User? Agent { get; set; }

    public DateTime VisitedAt { get; set; } = DateTime.UtcNow;
    public string? Note { get; set; }
    public Guid SupplierId { get; set; }
}