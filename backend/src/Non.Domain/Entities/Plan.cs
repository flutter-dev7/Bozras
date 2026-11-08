using Non.Domain.Common;

namespace Non.Domain.Entities;

public class Plan : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public decimal PricePerMonth { get; set; }
    public int? MaxShops { get; set; }
    public int? MaxStaff { get; set; }
    public bool IsActive { get; set; } = true;
}