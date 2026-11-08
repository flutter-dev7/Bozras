using Non.Domain.Common;
using Non.Domain.Enums;

namespace Non.Domain.Entities;

public class Location : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public LocationType Type { get; set; }

    public Guid? ParentId { get; set; }
    public Location? Parent { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<Location> Children { get; set; } = new List<Location>();
}