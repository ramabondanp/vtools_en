package com.omarea.vtools.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.omarea.common.shared.FileWrite
import com.omarea.common.shared.MagiskExtend
import com.omarea.vtools.databinding.FragmentMagiskPropsBinding
import java.io.File

class FragmentMagiskProps : Fragment() {
    private var _binding: FragmentMagiskPropsBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMagiskPropsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.magiskProps.setText(MagiskExtend.getProps())
        binding.magiskPropsReset.setOnClickListener {
            binding.magiskProps.setText(MagiskExtend.getProps())
        }
        binding.magiskPropsSave.setOnClickListener {
            val context = requireContext()
            if (FileWrite.writePrivateFile((binding.magiskProps.text.toString() + "\n").toByteArray(), "magisk_system.prop", context)) {
                val file = FileWrite.getPrivateFilePath(context, "magisk_system.prop")
                if (MagiskExtend.updateProps(file)) {
                    binding.magiskProps.setText(MagiskExtend.getProps())
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
