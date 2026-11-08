using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class Category : BaseEntity, ITenantEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid SupplierId { get; set; }
}