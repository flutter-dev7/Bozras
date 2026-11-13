using Bozras.Domain.Common;
using Bozras.Domain.Enums;

namespace Bozras.Domain.Entities;

public class OrderStatusHistory : ITenantEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public OrderStatus Status { get; set; }

    public Guid ChangedByUserId { get; set; }
    public User? ChangedByUser { get; set; }

    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public Guid SupplierId { get; set; }
}