using Non.Domain.Common;
using Non.Domain.Enums;

namespace Non.Domain.Entities;

public class StockMovement : BaseEntity, ITenantEntity
{
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }

    public StockMovementType Type { get; set; }
    public int Quantity { get; set; }
    public int BalanceAfter { get; set; }

    public Guid? OrderId { get; set; }
    public string? Comment { get; set; }

    public Guid? CreatedByUserId { get; set; }
    public User? CreatedByUser { get; set; }
    public Guid SupplierId { get; set; }
}