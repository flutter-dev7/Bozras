using Bozras.Application.Interfaces.Services;

namespace Bozras.Infrastructure.Tenancy;

public class TenantContext : ITenantContext
{
    public Guid? SupplierId { get; private set; }

    public Guid RequireSupplierId() =>
        SupplierId ?? throw new InvalidOperationException("Не определён поставщик.");

    public void Set(Guid? supplierId) => SupplierId = supplierId;
}