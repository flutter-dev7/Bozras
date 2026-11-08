namespace Non.Application.Interfaces.Services;

public interface ITenantContext
{
    Guid? SupplierId { get; }

    Guid RequireSupplierId();

    void Set(Guid? supplierId);
}