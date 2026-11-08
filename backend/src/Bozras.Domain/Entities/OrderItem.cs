using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class OrderItem : BaseEntity, ITenantEntity
{
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public Guid ProductId { get; set; }
    public Product? Product { get; set; }

    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    public decimal LineTotal => Quantity * UnitPrice;
    public Guid SupplierId { get; set; }
}