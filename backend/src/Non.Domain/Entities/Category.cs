using Non.Domain.Common;

namespace Non.Domain.Entities;

public class Category : BaseEntity, ITenantEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid SupplierId { get; set; }
}