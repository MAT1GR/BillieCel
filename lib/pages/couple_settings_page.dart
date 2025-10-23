import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoupleSettingsPage extends StatefulWidget {
  const CoupleSettingsPage({super.key});

  @override
  State<CoupleSettingsPage> createState() => _CoupleSettingsPageState();
}

class _CoupleSettingsPageState extends State<CoupleSettingsPage> {
  final _partnerEmailController = TextEditingController();
  String? _currentCoupleStatus;
  String? _partnerUsername;
  String? _coupleId;
  String? _coupleUser1Id;
  String? _coupleUser2Id;

  @override
  void initState() {
    super.initState();
    _loadCoupleStatus();
  }

  Future<void> _loadCoupleStatus() async {
    debugPrint('[_loadCoupleStatus] Starting...');
    final userId = supabase.auth.currentUser!.id;
    debugPrint('[_loadCoupleStatus] Current User ID: $userId');
    try {
      final response = await supabase
          .from('couples')
          .select('id, status, user1_id, user2_id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .maybeSingle();

      debugPrint('[_loadCoupleStatus] Supabase Response: $response');

      if (response != null) {
        final partnerId = response['user1_id'] == userId ? response['user2_id'] : response['user1_id'];
        final partnerProfileResponse = await supabase
            .from('profiles')
            .select('username')
            .eq('id', partnerId)
            .maybeSingle();

        setState(() {
          _coupleId = response['id'];
          _currentCoupleStatus = response['status'];
          _coupleUser1Id = response['user1_id'];
          _coupleUser2Id = response['user2_id'];
          _partnerUsername = partnerProfileResponse?['username'];
        });
        debugPrint('[_loadCoupleStatus] State updated: coupleId=$_coupleId, status=$_currentCoupleStatus, user1=$_coupleUser1Id, user2=$_coupleUser2Id, partnerUsername=$_partnerUsername');
      } else {
        debugPrint('[_loadCoupleStatus] No couple found for user.');
        setState(() {
          _currentCoupleStatus = null;
          _partnerUsername = null;
          _coupleId = null;
          _coupleUser1Id = null;
          _coupleUser2Id = null;
        });
      }
    } catch (e) {
      debugPrint('[_loadCoupleStatus] Error loading couple status: $e');
      setState(() {
        _currentCoupleStatus = null;
        _partnerUsername = null;
        _coupleId = null;
        _coupleUser1Id = null;
        _coupleUser2Id = null;
      });
    }
  }

  Future<void> _invitePartner() async {
    final partnerEmail = _partnerEmailController.text.trim();
    if (partnerEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el email de tu pareja.')),
      );
      return;
    }

    final currentUserId = supabase.auth.currentUser!.id;

    // First, find the partner's user ID from their email
    final partnerId = await supabase.rpc(
      'get_user_id_by_email',
      params: {'user_email': partnerEmail},
    ) as String?;

    if (partnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un usuario con ese email.')),
      );
      return;
    }

    if (partnerId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes invitarte a ti mismo.')),
      );
      return;
    }

    try {
      await supabase.from('couples').insert({
        'user1_id': currentUserId,
        'user2_id': partnerId,
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación enviada con éxito!')),
      );
      _partnerEmailController.clear();
      _loadCoupleStatus(); // Reload status to show pending invitation
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique constraint violation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe una invitación o pareja con este usuario.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar invitación: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    }
  }

  Future<void> _acceptInvitation() async {
    debugPrint('[CoupleSettingsPage] _acceptInvitation: Starting...');
    if (_coupleId == null) {
      debugPrint('[CoupleSettingsPage] _acceptInvitation: _coupleId is null, returning.');
      return;
    }
    try {
      debugPrint('[CoupleSettingsPage] _acceptInvitation: Updating couple status to active for coupleId=$_coupleId');
      await supabase.from('couples').update({'status': 'active'}).eq('id', _coupleId as String);
      debugPrint('[CoupleSettingsPage] _acceptInvitation: Couple status updated.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación aceptada!')),
      );
      await _loadCoupleStatus(); // Reload status to update UI
      debugPrint('[CoupleSettingsPage] _acceptInvitation: _loadCoupleStatus completed.');
    } on PostgrestException catch (e) {
      debugPrint('[CoupleSettingsPage] _acceptInvitation PostgrestException: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar invitación: ${e.message}')),
      );
    } catch (e) {
      debugPrint('[CoupleSettingsPage] _acceptInvitation Unexpected Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar invitación: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelOrDeclineInvitation() async {
    if (_coupleId == null) return;
    try {
      await supabase.from('couples').delete().eq('id', _coupleId as String);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación rechazada.')),
      );
      _loadCoupleStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar invitación: ${e.toString()}')),
      );
    }
  }

  Future<void> _leaveCouple() async {
    if (_coupleId == null) return;
    try {
      await supabase.from('couples').delete().eq('id', _coupleId as String);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has dejado la pareja.')),
      );
      _loadCoupleStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al dejar la pareja: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _partnerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Pareja')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de la Pareja',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_currentCoupleStatus == null) ...[
              const Text('Actualmente no tienes una pareja vinculada.'),
              const SizedBox(height: 24),
              TextField(
                controller: _partnerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email de tu pareja',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _invitePartner,
                child: const Text('Invitar Pareja'),
              ),
            ] else if (_currentCoupleStatus == 'pending') ...[
              if (supabase.auth.currentUser!.id == _coupleUser1Id) ...[ // Current user is the inviter
                Text('Invitación enviada a: ${_partnerUsername ?? '[cargando...]'}'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _cancelOrDeclineInvitation,
                  child: const Text('Cancelar Invitación'),
                ),
              ] else if (supabase.auth.currentUser!.id == _coupleUser2Id) ...[ // Current user is the invitee
                Text('Invitación de: ${_partnerUsername ?? '[cargando...]'}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _acceptInvitation,
                      child: const Text('Aceptar Invitación'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _cancelOrDeclineInvitation,
                      child: const Text('Rechazar Invitación'),
                    ),
                  ],
                ),
              ],
            ] else if (_currentCoupleStatus == 'active') ...[
              Text('Vinculado con: ${_partnerUsername ?? '[cargando...]'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _leaveCouple,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Dejar Pareja'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
