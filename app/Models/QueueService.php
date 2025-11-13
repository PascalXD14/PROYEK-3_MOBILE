<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QueueService extends Model
{
    use HasFactory;

    protected $table = 'queue_service';

    protected $fillable = [
        'user_id',
        'queue_number',
        'date',
        'time',
        'name',
        'address',
        'phone',
        'vehicle',
        'type',
    ];

    // Relasi ke user
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
