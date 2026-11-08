using Non.Domain.Common;

namespace Non.Domain.Entities;

public class ServiceArea : BaseEntity
{
    public Guid SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public Guid LocationId { get; set; }
    public Location? Location { get; set; }
}