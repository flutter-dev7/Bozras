using Non.Domain.Common;
using Non.Domain.Enums;

namespace Non.Domain.Entities;

public class Shop : BaseEntity, ITenantEntity
{
    public Guid SupplierId { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? ContactName { get; set; }

    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public Guid? ProfileId { get; set; }
    public ShopProfile? Profile { get; set; }

    public ShopConnectionStatus Status { get; set; } = ShopConnectionStatus.Active;

    public decimal? DebtLimit { get; set; }
    public bool IsActive { get; set; } = true;

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}