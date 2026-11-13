using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class Plan : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public decimal PricePerMonth { get; set; }
    public int? MaxShops { get; set; }
    public int? MaxStaff { get; set; }
    public bool IsActive { get; set; } = true;
}