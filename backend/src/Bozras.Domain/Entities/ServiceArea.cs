using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class ServiceArea : BaseEntity
{
    public Guid SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public Guid LocationId { get; set; }
    public Location? Location { get; set; }
}