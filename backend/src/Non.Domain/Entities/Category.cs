using Non.Domain.Common;

namespace Non.Domain.Entities;

public class Category : BaseEntity
{
    public string Name { get; set; } = string.Empty;
}