using Bozras.Application.Common;

namespace Bozras.Application.Interfaces.Services;

public interface IPushQueue
{
    void Enqueue(PushMessage message);
}