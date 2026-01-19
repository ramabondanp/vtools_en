package com.omarea.vtools.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.omarea.common.shared.FileWrite
import com.omarea.common.shared.MagiskExtend
import com.omarea.vtools.databinding.FragmentMagiskAfterstartBinding
import java.io.File

class FragmentMagiskAfterStart : Fragment() {
    private var _binding: FragmentMagiskAfterstartBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMagiskAfterstartBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.magiskAfterstart.setText(MagiskExtend.getServiceSH())
        binding.magiskAfterstartReset.setOnClickListener {
            binding.magiskAfterstart.setText(MagiskExtend.getServiceSH())
        }
        binding.magiskAfterstartSave.setOnClickListener {
            val context = requireContext()
            if (FileWrite.writePrivateFile((binding.magiskAfterstart.text.toString() + "\n").toByteArray(), "magisk_service.sh", context)) {
                val file = FileWrite.getPrivateFilePath(context, "magisk_service.sh")
                if (MagiskExtend.updateServiceSH(file)) {
                    binding.magiskAfterstart.setText(MagiskExtend.getServiceSH())
                    Toast.makeText(context, "Changes saved. Take effect after reboot.", Toast.LENGTH_LONG).show()
                    File(file).delete()
                } else {
                    Toast.makeText(context, "Magisk image has insufficient space. Operation failed.", Toast.LENGTH_LONG).show()
                }
            } else {
                Toast.makeText(context, "Save failed.", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
