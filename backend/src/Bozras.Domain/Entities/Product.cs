using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class Product : BaseEntity, ITenantEntity
{
    public string Name { get; set; } = string.Empty;
    public int? WeightInGrams { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    public string Unit { get; set; } = "шт";
    public int StockQuantity { get; set; }

    public Guid? CategoryId { get; set; }
    public Category? Category { get; set; }
    public Guid SupplierId { get; set; }
}