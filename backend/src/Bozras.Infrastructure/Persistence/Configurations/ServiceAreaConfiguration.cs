using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Bozras.Domain.Entities;

namespace Bozras.Infrastructure.Persistence.Configurations;

public class ServiceAreaConfiguration : IEntityTypeConfiguration<ServiceArea>
{
    public void Configure(EntityTypeBuilder<ServiceArea> builder)
    {
        builder.ToTable("ServiceAreas");
        builder.HasKey(a => a.Id);

        builder.HasOne(a => a.Supplier)
            .WithMany(s => s.ServiceAreas)
            .HasForeignKey(a => a.SupplierId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Location)
            .WithMany()
            .HasForeignKey(a => a.LocationId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(a => new { a.SupplierId, a.LocationId }).IsUnique();
    }
}