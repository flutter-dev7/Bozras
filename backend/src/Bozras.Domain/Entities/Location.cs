using Bozras.Domain.Common;
using Bozras.Domain.Enums;

namespace Bozras.Domain.Entities;

public class Location : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public LocationType Type { get; set; }

    public Guid? ParentId { get; set; }
    public Location? Parent { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<Location> Children { get; set; } = new List<Location>();
}