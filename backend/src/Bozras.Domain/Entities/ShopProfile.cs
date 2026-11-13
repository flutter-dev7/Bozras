using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class ShopProfile : BaseEntity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? ContactName { get; set; }

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public Guid? LocationId { get; set; }
    public Location? Location { get; set; }
}