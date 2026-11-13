using Bozras.Domain.Common;

namespace Bozras.Domain.Entities;

public class Setting : ITenantEntity
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public Guid SupplierId { get; set; }
}